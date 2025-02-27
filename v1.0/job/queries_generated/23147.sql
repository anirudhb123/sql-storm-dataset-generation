WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        0 AS level
    FROM
        aka_title m
    WHERE
        m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM
        aka_title m
    JOIN
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),
ActorRoles AS (
    SELECT
        c.person_id,
        c.movie_id,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY c.nr_order) AS role_order
    FROM
        cast_info c
    JOIN
        role_type r ON c.role_id = r.id
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
Companies AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
),
MovieInfo AS (
    SELECT
        m.id AS movie_id,
        COALESCE(mi.info, 'No Info Available') AS info,
        COALESCE(mn.note, 'No Note') AS note
    FROM
        title m
    LEFT JOIN
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN
        movie_info_idx mn ON mn.movie_id = m.id AND mn.info_type_id = (SELECT id FROM info_type WHERE info = 'Remark')
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT ar.person_id) AS total_actors,
    STRING_AGG(DISTINCT ar.role_name, ', ') AS roles,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(c.company_names, 'No Companies') AS companies,
    COALESCE(mi.info, 'No Info') AS movie_info,
    COALESCE(mi.note, 'No Note') AS movie_note,
    CASE
        WHEN COUNT(DISTINCT ar.person_id) > 10 THEN 'Blockbuster'
        WHEN COUNT(DISTINCT ar.person_id) BETWEEN 5 AND 10 THEN 'Moderate Hit'
        ELSE 'Indie Film'
    END AS box_office_potential
FROM
    MovieHierarchy mh
LEFT JOIN
    ActorRoles ar ON mh.movie_id = ar.movie_id
LEFT JOIN
    MovieKeywords mk ON mh.movie_id = mk.movie_id
LEFT JOIN
    Companies c ON mh.movie_id = c.movie_id
LEFT JOIN
    MovieInfo mi ON mh.movie_id = mi.movie_id
GROUP BY
    mh.movie_id, mh.title, mh.production_year, mi.info, mi.note
ORDER BY
    mh.production_year DESC, total_actors DESC;
