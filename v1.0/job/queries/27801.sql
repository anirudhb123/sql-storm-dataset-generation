
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS alternate_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.alternate_names,
        rm.keywords,
        ROW_NUMBER() OVER (ORDER BY rm.cast_count DESC, rm.production_year DESC) AS rank
    FROM 
        RankedMovies rm
    WHERE 
        rm.production_year >= 2000
)
SELECT 
    fm.rank AS Rank,
    fm.title AS Movie_Title,
    fm.production_year AS Production_Year,
    fm.cast_count AS Cast_Count,
    fm.alternate_names AS Alternate_Names,
    fm.keywords AS Keywords
FROM 
    FilteredMovies fm
WHERE 
    fm.cast_count >= 5
ORDER BY 
    fm.rank
LIMIT 10;
