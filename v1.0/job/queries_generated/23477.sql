WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank,
        COALESCE(SUM(mk.keyword IS NOT NULL)::int, 0) AS keyword_count
    FROM 
        aka_title a
    LEFT JOIN movie_keyword mk ON a.id = mk.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
FilteredMovies AS (
    SELECT 
        movie_title,
        production_year,
        year_rank,
        keyword_count
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 10 
        AND production_year >= 2000
),
ActorDetails AS (
    SELECT 
        cn.name AS actor_name,
        ci.movie_id,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY cn.name) AS actor_order
    FROM 
        cast_info ci
    JOIN aka_name cn ON ci.person_id = cn.person_id
)
SELECT 
    fm.movie_title,
    fm.production_year,
    COALESCE(STRING_AGG(ad.actor_name, ', ' ORDER BY ad.actor_order), 'No Actors') AS actor_list,
    fm.keyword_count,
    CASE 
        WHEN fm.keyword_count > 5 THEN 'Highly Taggable'
        WHEN fm.keyword_count BETWEEN 1 AND 5 THEN 'Moderately Taggable'
        ELSE 'Not Taggable'
    END AS taggable_status
FROM 
    FilteredMovies fm
LEFT JOIN ActorDetails ad ON fm.movie_id = ad.movie_id
GROUP BY 
    fm.movie_title, fm.production_year, fm.keyword_count
ORDER BY 
    fm.production_year DESC, fm.movie_title;
