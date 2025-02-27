WITH RankedMovies AS (
    SELECT 
        mt.title, 
        mt.production_year, 
        COUNT(ci.person_id) OVER (PARTITION BY mt.id) AS cast_count,
        RANK() OVER (ORDER BY COUNT(ci.person_id) DESC, mt.production_year DESC) AS rank
    FROM 
        aka_title mt 
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    WHERE 
        mt.production_year IS NOT NULL 
        AND mt.kind_id IS NOT NULL
        AND (mt.title NOT LIKE '%unreleased%' OR mt.title IS NULL)
),
FilteredMovies AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        rm.cast_count
    FROM 
        RankedMovies rm 
    WHERE 
        rm.rank <= 10
),
MovieDetails AS (
    SELECT 
        fm.title, 
        fm.production_year, 
        COALESCE(mi.info, 'No info available') AS movie_info,
        STRING_AGG(kw.keyword, ', ') AS keywords
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        movie_info mi ON fm.title = mi.info 
    LEFT JOIN 
        movie_keyword mk ON fm.title = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id 
    GROUP BY 
        fm.title, fm.production_year
),
PersonDetails AS (
    SELECT 
        ak.name AS actor_name, 
        ak.id AS actor_id,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name ak 
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name, ak.id
    HAVING 
        COUNT(ci.movie_id) > 1
)
SELECT 
    md.title, 
    md.production_year, 
    md.movie_info, 
    pd.actor_name, 
    pd.movie_count,
    CASE 
        WHEN md.production_year < 2000 THEN 'Classic' 
        WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent' 
    END AS era,
    CONCAT_WS(' | ', COALESCE(md.keywords, 'No keywords'), 'Info: ', COALESCE(md.movie_info, 'N/A')) AS summary
FROM 
    MovieDetails md
JOIN 
    PersonDetails pd ON EXISTS (
        SELECT 1 FROM cast_info ci WHERE ci.movie_id = md.title AND ci.person_id = pd.actor_id
    )
ORDER BY 
    md.production_year DESC, pd.movie_count DESC 
FETCH FIRST 5 ROWS ONLY;
