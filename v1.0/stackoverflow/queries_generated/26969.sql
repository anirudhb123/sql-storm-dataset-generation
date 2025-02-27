WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerName,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount,
        r.Row_Number,
        ROW_NUMBER() OVER (PARTITION BY ARRAY(SELECT UNNEST(string_to_array(p.Tags, ','))::varchar) ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        OwnerUserId,
        OwnerName,
        Tags,
        CommentCount,
        AnswerCount,
        TagRank
    FROM 
        RankedPosts 
    WHERE 
        TagRank <= 5
),
FinalOutput AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.OwnerUserId,
        fp.OwnerName,
        STRING_AGG(DISTINCT t.TagName, ', ') AS FilteredTags,
        json_build_object(
            'CommentCount', fp.CommentCount,
            'AnswerCount', fp.AnswerCount,
            'TagCount', array_length(string_to_array(fp.Tags, ','), 1)
        ) AS Stats
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        Tags t ON t.TagName = ANY(string_to_array(fp.Tags, ','))
    GROUP BY 
        fp.PostId, fp.Title, fp.CreationDate, fp.OwnerUserId, fp.OwnerName, fp.CommentCount, fp.AnswerCount
)
SELECT 
    *
FROM 
    FinalOutput
ORDER BY 
    CreationDate DESC
LIMIT 50;
