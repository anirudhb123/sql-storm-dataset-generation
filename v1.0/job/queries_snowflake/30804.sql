
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mh.level < 3 
),
MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ci.person_id) AS num_cast_members,
        LISTAGG(DISTINCT an.name, ', ') WITHIN GROUP (ORDER BY an.name) AS cast_names,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_within_year
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),
TitleInfo AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mi.info AS movie_info,
        it.info AS info_type
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_info mi ON mt.id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        it.info IS NOT NULL
),
FinalResults AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.num_cast_members,
        md.cast_names,
        ti.movie_info
    FROM 
        MovieDetails md
    LEFT JOIN 
        TitleInfo ti ON md.movie_id = ti.movie_id
    WHERE 
        md.num_cast_members > 5 
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.num_cast_members,
    fr.cast_names,
    fr.movie_info,
    CASE 
        WHEN fr.num_cast_members > 10 THEN 'Popular'
        WHEN fr.num_cast_members BETWEEN 6 AND 10 THEN 'Moderate'
        ELSE 'Less Known'
    END AS popularity_category
FROM 
    FinalResults fr
ORDER BY 
    fr.production_year DESC, 
    fr.num_cast_members DESC;
