package com.meetup.clusterdns

import java.net.InetAddress

import com.github.mkroli.dns4s.dsl._
import com.meetup.logging.Logging

import scala.util.{Failure, Success, Try}

trait HostResolver {
  def resolve(host: String): MessageModifier
}

case object DefaultResolver extends HostResolver with Logging {
  def resolve(host: String) = {
    log.info(s"Resolving host: $host")
    Try(InetAddress.getByName(host)) match {
      case Success(addr: InetAddress) =>
        Answers(RRName(host) ~ ARecord(addr.getHostAddress))

      case Failure(e) =>
        ServerFailure
    }
  }
}
