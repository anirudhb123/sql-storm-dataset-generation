WITH MovieDetails AS (
  SELECT
    t.id AS movie_id,
    t.title AS movie_title,
    t.production_year,
    k.keyword AS movie_keyword,
    GROUP_CONCAT(DISTINCT c.role_id) AS role_ids,
    GROUP_CONCAT(DISTINCT ci.note) AS cast_notes
  FROM
    aka_title AS t
  JOIN
    movie_keyword AS mk ON t.id = mk.movie_id
  JOIN
    keyword AS k ON mk.keyword_id = k.id
  LEFT JOIN
    cast_info AS ci ON t.id = ci.movie_id
  LEFT JOIN
    role_type AS r ON ci.role_id = r.id
  WHERE
    t.production_year >= 2000
  GROUP BY
    t.id, t.title, t.production_year, k.keyword
),
ActorDetails AS (
  SELECT
    a.id AS person_id,
    a.name AS actor_name,
    a.gender,
    GROUP_CONCAT(DISTINCT ci.movie_id) AS movies_played,
    GROUP_CONCAT(DISTINCT ci.nr_order) AS order_numbers
  FROM
    aka_name AS a
  JOIN
    cast_info AS ci ON a.person_id = ci.person_id
  GROUP BY
    a.id, a.name, a.gender
)
SELECT
  md.movie_id,
  md.movie_title,
  md.production_year,
  md.movie_keyword,
  ad.actor_name,
  ad.gender,
  ad.movies_played,
  ad.order_numbers,
  md.cast_notes
FROM
  MovieDetails md
JOIN
  ActorDetails ad ON md.role_ids LIKE CONCAT('%', ad.person_id, '%')
ORDER BY
  md.production_year DESC, md.movie_title ASC;
