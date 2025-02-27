WITH RankedTitles AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS title_rank
    FROM aka_title a
    JOIN movie_keyword mk ON a.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
),
FeaturedCast AS (
    SELECT 
        c.movie_id,
        p.name AS actor_name,
        rt.movie_title,
        rt.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS cast_rank
    FROM cast_info c
    JOIN aka_name p ON c.person_id = p.person_id
    JOIN RankedTitles rt ON c.movie_id = rt.movie_title
    WHERE rt.title_rank = 1
),
MovieDetails AS (
    SELECT 
        rt.movie_title,
        COUNT(fc.actor_name) AS actor_count,
        STRING_AGG(fc.actor_name, ', ') AS actors_list,
        rt.production_year
    FROM RankedTitles rt
    JOIN FeaturedCast fc ON rt.movie_title = fc.movie_title
    GROUP BY rt.movie_title, rt.production_year
)
SELECT 
    md.movie_title,
    md.production_year,
    md.actor_count,
    md.actors_list
FROM MovieDetails md
WHERE md.actor_count > 5
ORDER BY md.production_year DESC, md.movie_title;
