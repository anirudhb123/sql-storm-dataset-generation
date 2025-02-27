WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2020
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        m.id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS year_rank,
        COUNT(DISTINCT c.id) AS total_cast
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        rm.year_rank,
        rm.total_cast
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        RankedMovies rm ON mh.movie_id = rm.id
)
SELECT 
    md.title AS Movie_Title,
    md.production_year AS Production_Year,
    md.year_rank AS Year_Rank,
    COALESCE(md.total_cast, 0) AS Total_Cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS Cast_Names,
    COUNT(DISTINCT mk.keyword) AS Related_Keywords
FROM 
    MovieDetails md
LEFT JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON md.movie_id = mk.movie_id
WHERE 
    md.year_rank <= 5 -- Limiting to top 5 movies of each year
GROUP BY 
    md.movie_id, md.title, md.production_year, md.year_rank, md.total_cast
ORDER BY 
    md.production_year DESC, md.year_rank;

This query generates a list of movies produced from the year 2020 onward, ranked by year, computing various statistics about their casts and related keywords. It leverages recursive CTEs to build a hierarchy of linked movies, incorporates window functions to analyze rank structure, applies outer joins to ensure comprehensive data retrieval, and uses string aggregation to collate cast names while counting relevant keywords.
