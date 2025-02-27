WITH MovieTitleInfo AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ARRAY_AGG(DISTINCT c.name) AS cast_names
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN aka_name a ON cc.subject_id = a.person_id
    JOIN cast_info ci ON ci.movie_id = t.id AND ci.person_id = a.person_id
    JOIN name n ON n.id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
RichMovieInfo AS (
    SELECT 
        mti.title_id,
        mti.title,
        mti.production_year,
        mti.keyword,
        mti.cast_names,
        ARRAY_AGG(DISTINCT mi.info ORDER BY mi.info_type_id) AS additional_info,
        ARRAY_AGG(DISTINCT c.name ORDER BY c.id) AS company_names
    FROM MovieTitleInfo mti
    LEFT JOIN movie_info mi ON mti.title_id = mi.movie_id
    LEFT JOIN movie_companies mc ON mti.title_id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    GROUP BY mti.title_id, mti.title, mti.production_year, mti.keyword, mti.cast_names
)
SELECT 
    rmi.title,
    rmi.production_year,
    rmi.keyword,
    rmi.cast_names,
    STRING_AGG(rmi.additional_info, ', ') AS collected_info,
    STRING_AGG(DISTINCT rmi.company_names, ', ') AS involved_companies
FROM RichMovieInfo rmi
GROUP BY 
    rmi.title, rmi.production_year, rmi.keyword, rmi.cast_names
ORDER BY 
    rmi.production_year DESC, rmi.title;
