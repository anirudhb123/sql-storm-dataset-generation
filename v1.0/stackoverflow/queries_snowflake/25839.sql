
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(ans.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts ans ON ans.ParentId = p.Id AND ans.PostTypeId = 2
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName
),
TagStats AS (
    SELECT 
        tag AS TagName,
        COUNT(*) AS PostCount
    FROM (
        SELECT 
            TRIM(value) AS tag
        FROM 
            Posts p,
            LATERAL SPLIT_TO_TABLE(LOWER(p.Tags), '><') AS value
        WHERE 
            p.Tags IS NOT NULL
    ) AS tags
    GROUP BY 
        tag
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStats
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.CreationDate,
    pd.OwnerDisplayName,
    pd.CommentCount,
    pd.AnswerCount,
    pd.UpVotes,
    pd.DownVotes,
    tt.TagName,
    tt.PostCount
FROM 
    PostDetails pd
JOIN 
    TopTags tt ON tt.TagName IN (SELECT TRIM(value) FROM LATERAL SPLIT_TO_TABLE(pd.Tags, '><') AS value)
WHERE 
    tt.TagRank <= 5 
ORDER BY 
    pd.CreationDate DESC, pd.PostId;
