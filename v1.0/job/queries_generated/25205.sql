WITH MovieDetails AS (
    SELECT t.title, 
           t.production_year, 
           t.imdb_index, 
           ARRAY_AGG(DISTINCT k.keyword) AS keywords,
           c.name AS company_name
    FROM aka_title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, c.name
),
ActorDetails AS (
    SELECT a.name, 
           a.person_id, 
           ARRAY_AGG(DISTINCT r.role) AS roles,
           ARRAY_AGG(DISTINCT mc.movie_id) AS movies
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN role_type r ON ci.role_id = r.id
    LEFT JOIN movie_companies mc ON ci.movie_id = mc.movie_id
    WHERE a.name IS NOT NULL
    GROUP BY a.name, a.person_id
),
InfoSummary AS (
    SELECT p.info, 
           p.note, 
           a.name AS actor_name, 
           t.title AS movie_title
    FROM person_info p
    JOIN aka_name a ON p.person_id = a.person_id
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN aka_title t ON ci.movie_id = t.id
    WHERE p.info_type_id IN (SELECT id FROM info_type WHERE info = 'awards')
)
SELECT md.title, 
       md.production_year,
       md.keywords,
       ad.name AS actor_name,
       ad.roles,
       is.info AS award_info,
       is.note AS award_note
FROM MovieDetails md
LEFT JOIN ActorDetails ad ON md.title ILIKE '%' || ad.movies[1] || '%'
LEFT JOIN InfoSummary is ON md.title = is.movie_title
ORDER BY md.production_year DESC, md.title;
