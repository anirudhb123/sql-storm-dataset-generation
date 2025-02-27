WITH ranked_titles AS (
    SELECT
        at.title,
        COUNT(DISTINCT cc.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT ci.note, '; ') AS role_notes
    FROM
        aka_title at
    LEFT JOIN
        complete_cast cc ON at.movie_id = cc.movie_id
    LEFT JOIN
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY
        at.title
), 
filtered_titles AS (
    SELECT
        title,
        cast_count,
        aka_names,
        role_notes,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS title_rank
    FROM
        ranked_titles
    WHERE
        cast_count > 5
)
SELECT 
    ft.title,
    ft.cast_count,
    ft.aka_names,
    ft.role_notes
FROM 
    filtered_titles ft
WHERE 
    ft.title_rank <= 10
ORDER BY 
    ft.cast_count DESC;
