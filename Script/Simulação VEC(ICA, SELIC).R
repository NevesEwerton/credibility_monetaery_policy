####################################################################
###Índice de Credibilidade da Política Monetária de Mendonça 2007###
####################################################################

library(Quandl)
library(tidyverse)
library(vars)
library(readxl)
my.api.key <- 'Hz9YrPYaD41AWNKFswcc'
Quandl.api_key(my.api.key)
my.code <- 'BCB/432'

df.selic <- Quandl(code = my.code, collapse = "monthly",
                   start_date = '2011-01-01',
                   end_date = '2018-12-31')
selic = ts(df.selic$Value, start = 1, end = 96, 
           frequency = 1)
SELIC = rev(selic)

ICa = read_excel("Mono.xls", range = 'H2:H98',
                  col_types = 'numeric')
ICa = ts(ICa, frequency = 1)

data = cbind(ICa, SELIC)
###TEste de Raiz Unitária
KPSS.testICa <- ur.kpss(ICa, type = "tau", lags = "short")
KPSS.testICck <- ur.kpss(ICck, type = "tau", lags = "short")
KPSS.testICm <- ur.kpss(ICm, type = "tau", lags = "short")
KPSS.testLSELIC <- ur.kpss(SELIC, type = "tau", lags = "short")

ERS.testLICa <- ur.ers(ICa, type = "DF-GLS", model = "trend")
ERS.testLICck <- ur.ers(ICck, type = "DF-GLS", model = "trend")
ERS.testLICm <- ur.ers(ICm, type = "DF-GLS", model = "trend")
ERS.testLSELIC <- ur.ers(SELIC, type = "DF-GLS", model = "trend")
PP.test(ICa)
PP.test(SELIC)
UniRootICa <- ur.ers(ICa, type = c("DF-GLS"), model = c("trend"))
library(egcm)
pgff.test(ICa, detrend = TRUE)
pgff.test(SELIC, detrend = FALSE)
pgff.test(data)
pgff.test(ICa)

#Selecionado a defasagem
def <- VARselect(data,lag.max=12,type="both")
def$selection


### Teste de Cointegração
jo.eigen <- ca.jo(data, type='eigen', K=5, ecdet='trend',
                  spec='longrun')
summary(jo.eigen)

### Modelo VEC
vec <- cajorls(jo.eigen, r=1)

vec$beta

### Visualização dos coeficientes e do R2
summary(vec$rlm)

### VEC para VAR
vec.level <- vec2var(jo.eigen, r=1)
#Função Impulso Resposta
irf = irf(vec.level, impulse='ICa', response='SELIC',
          n.ahead = 12, boot=T, ortho=T, cumulative=F)
lags = 1:13
df.irf <- data.frame(irf=irf$irf, lower=irf$Lower, upper=irf$Upper,
                     lags=lags)
colnames(df.irf) <- c('irf', 'lower', 'upper', 'lags')
number_ticks <- function(n) {function(limits) pretty(limits, n)}


ggplot(data = df.irf,aes(x=lags,y=irf)) +
  geom_line(aes(y = upper), colour = 'lightblue2') +
  geom_line(aes(y = lower), colour = 'lightblue')+
  geom_line(aes(y = irf), size=.8)+
  geom_ribbon(aes(x=lags, ymax=upper,
                  ymin=lower),
              fill="blue", alpha=.1) +
  xlab("") + ylab("Taxa Selic") +
  ggtitle("Resposta ao Impulso em ICa") +
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        plot.margin = unit(c(2,10,2,10), "mm"))+
  geom_line(colour = 'black')+
  scale_x_continuous(breaks=number_ticks(13))+
  theme_bw()

### Decomposição de Variância
fevd(vec.level, n.ahead=12)
library(het.test)
library(aod)
### VAR(3)
var3 <- VAR(data, p = 6, type = "both")
serial.test(var3)
#TEste de Heterocedasticidade dos Resíduos
whites.htest(var3)

#Teste de Normalidade dos Resíduos
resíduos = vec.level$resid
shapiro.test(resíduos)
plot(resíduos2)
hist(resíduos2)
#Teste de Heterocedasticidade
library(lmtest)
bptest(resíduos2)
library(aod)
### Teste de Wald
var3 <- VAR(data, p=6, type='both')
### Wald Test 01: SELIC não granger causa Índice
wald.test(b=coef(var3$varresult[[1]]),
          Sigma=vcov(var3$varresult[[1]]),
          Terms=c(2,4,6,8,10))

### Wald Test 02: Índice não granger causa SELIC
wald.test(b=coef(var3$varresult[[2]]),
          Sigma=vcov(var3$varresult[[2]]),
          Terms= c(1,3,5,7,9))
result = var3$varresult
summary(result)
plot(stability(var3))

causality(var3, cause = "ICa")$Granger
causality(var3, cause = "SELIC")$Granger
