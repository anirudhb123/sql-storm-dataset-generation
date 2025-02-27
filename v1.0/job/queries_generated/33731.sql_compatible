
WITH RECURSIVE MovieHierarchy AS (
    
    SELECT t.id AS movie_id, t.title AS movie_title, t.production_year, NULL AS parent_id
    FROM title t
    WHERE t.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT t.id AS movie_id, t.title AS movie_title, t.production_year, t.episode_of_id AS parent_id
    FROM title t
    JOIN MovieHierarchy mh ON t.episode_of_id = mh.movie_id
),
RankedMovies AS (
    
    SELECT mh.movie_id, mh.movie_title, mh.production_year,
           RANK() OVER (PARTITION BY mh.production_year ORDER BY mh.movie_title) AS rank_within_year
    FROM MovieHierarchy mh
),
MovieDetails AS (
    
    SELECT rm.movie_id, rm.movie_title, rm.production_year, rm.rank_within_year,
           STRING_AGG(DISTINCT CONCAT(a.name, ' as ', r.role), ', ') AS cast_list,
           STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM RankedMovies rm
    LEFT JOIN complete_cast cc ON cc.movie_id = rm.movie_id
    LEFT JOIN cast_info ci ON ci.movie_id = cc.movie_id
    LEFT JOIN aka_name a ON a.person_id = ci.person_id
    LEFT JOIN role_type r ON r.id = ci.role_id
    LEFT JOIN movie_keyword mk ON mk.movie_id = rm.movie_id
    LEFT JOIN keyword k ON k.id = mk.keyword_id
    GROUP BY rm.movie_id, rm.movie_title, rm.production_year, rm.rank_within_year
),
FilteredMovies AS (
    
    SELECT *
    FROM MovieDetails
    WHERE production_year BETWEEN 2000 AND 2023
      AND (rank_within_year IS NOT NULL OR cast_list IS NOT NULL)
)

SELECT fm.movie_id,
       fm.movie_title,
       COALESCE(CAST(fm.production_year AS VARCHAR), 'Unknown Year') AS production_year,
       COALESCE(fm.cast_list, 'No Cast Available') AS cast_list,
       COALESCE(fm.keywords, 'No Keywords Available') AS keywords
FROM FilteredMovies fm
ORDER BY fm.production_year DESC, fm.rank_within_year;
