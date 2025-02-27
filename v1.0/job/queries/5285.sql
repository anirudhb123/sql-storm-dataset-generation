WITH MovieDetails AS (
    SELECT t.id AS title_id, t.title, t.production_year, t.kind_id, COUNT(DISTINCT mc.company_id) AS company_count
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    GROUP BY t.id, t.title, t.production_year, t.kind_id
),
ActorDetails AS (
    SELECT ci.movie_id, COUNT(DISTINCT ci.person_id) AS actor_count, STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    GROUP BY ci.movie_id
),
KeywordDetails AS (
    SELECT mk.movie_id, STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
InfoDetails AS (
    SELECT mi.movie_id, STRING_AGG(DISTINCT mi.info, '; ') AS infos
    FROM movie_info mi
    GROUP BY mi.movie_id
)
SELECT md.title, md.production_year, md.company_count, ad.actor_count, ad.actors, kd.keywords, id.infos
FROM MovieDetails md
LEFT JOIN ActorDetails ad ON md.title_id = ad.movie_id
LEFT JOIN KeywordDetails kd ON md.title_id = kd.movie_id
LEFT JOIN InfoDetails id ON md.title_id = id.movie_id
WHERE md.production_year >= 2000
ORDER BY md.production_year DESC, md.company_count DESC;
