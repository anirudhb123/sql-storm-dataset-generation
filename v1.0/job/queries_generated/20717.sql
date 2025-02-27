WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rn,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        COUNT(DISTINCT c.id) AS actor_count
    FROM 
        aka_title at
    JOIN 
        cast_info c ON at.id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        c.nr_order IS NOT NULL
    GROUP BY 
        at.id, at.production_year
), ActorMovieInfo AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.actor_names,
        rm.actor_count,
        mi.info AS movie_note,
        COALESCE(k.keyword, 'No Keywords') AS movie_keywords,
        ROW_NUMBER() OVER (PARTITION BY rm.production_year ORDER BY rm.actor_count DESC) AS rank_by_actors
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info mi ON rm.production_year = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON rm.production_year = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
), FilteredMovies AS (
    SELECT 
        ami.*,
        CASE 
            WHEN ami.actor_count > 5 THEN 'Popular' 
            WHEN ami.actor_count BETWEEN 3 AND 5 THEN 'Moderate' 
            ELSE 'Unpopular' 
        END AS popularity,
        COUNT(*) OVER (PARTITION BY ami.popularity) AS popularity_count
    FROM 
        ActorMovieInfo ami
    WHERE 
        ami.actor_count IS NOT NULL
        AND ami.actor_count > 3
)
SELECT 
    fm.movie_title,
    fm.production_year,
    fm.actor_names,
    fm.popularity,
    fm.popularity_count,
    fm.movie_note,
    fm.movie_keywords
FROM 
    FilteredMovies fm
WHERE 
    fm.rank_by_actors <= 10
ORDER BY 
    fm.production_year DESC, fm.popularity_count DESC;
