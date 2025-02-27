WITH RankedTitles AS (
    SELECT 
        a.person_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS title_rank,
        COUNT(DISTINCT k.keyword) OVER (PARTITION BY a.person_id) AS keyword_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL AND
        (t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%') OR t.kind_id IS NULL) 
),

TitleDetails AS (
    SELECT 
        rt.person_id,
        rt.title,
        rt.production_year,
        rt.title_rank,
        rt.keyword_count,
        COALESCE(cn.name, 'Unknown Company') AS company_name,
        SUM(mci.note IS NOT NULL)::int AS has_notes_count -- how many movies have notes
    FROM 
        RankedTitles rt
    LEFT JOIN 
        complete_cast cc ON rt.person_id = cc.subject_id
    LEFT JOIN 
        movie_companies mc ON cc.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.imdb_id
    LEFT JOIN 
        movie_info mi ON rt.production_year = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
    GROUP BY 
        rt.person_id, rt.title, rt.production_year, rt.title_rank, rt.keyword_count, cn.name
)

SELECT 
    td.person_id,
    td.title,
    td.production_year,
    td.title_rank,
    td.keyword_count,
    td.company_name,
    td.has_notes_count
FROM 
    TitleDetails td
WHERE 
    td.title_rank = 1 AND -- only top-ranked title
    (td.keyword_count > 0 OR (td.company_name IS NULL AND td.has_notes_count > 0)) -- must have keywords or unknown company with notes
ORDER BY 
    td.person_id, td.production_year DESC;

This SQL query is designed to gather detailed movie title information associated with people, while also considering various conditions like the presence of keywords and companies involved in the production of movies. The use of Common Table Expressions (CTEs), window functions, conditional aggregation, and outer joins introduces complexity that allows for a broad exploration of the relationships in the schema.
