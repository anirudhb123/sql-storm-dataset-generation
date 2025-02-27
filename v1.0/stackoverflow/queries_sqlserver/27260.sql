
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        users.DisplayName AS OwnerDisplayName,
        pt.Name AS PostType,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS HistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        Users users ON p.OwnerUserId = users.Id
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.ViewCount, users.DisplayName, pt.Name
),
TopTags AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(Tags, ',') 
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        value
    ORDER BY 
        PostCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
TagStats AS (
    SELECT 
        pd.PostId,
        STRING_AGG(tt.TagName, ', ') AS TopTags
    FROM 
        PostDetails pd
    JOIN 
        Posts p ON pd.PostId = p.Id
    JOIN 
        TopTags tt ON tt.TagName IN (SELECT value FROM STRING_SPLIT(p.Tags, ','))
    GROUP BY 
        pd.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.OwnerDisplayName,
    pd.PostType,
    pd.CreationDate,
    pd.ViewCount,
    pd.UpVotes,
    pd.DownVotes,
    pd.CommentCount,
    pd.HistoryCount,
    COALESCE(ts.TopTags, 'N/A') AS TopTags
FROM 
    PostDetails pd
LEFT JOIN 
    TagStats ts ON pd.PostId = ts.PostId
ORDER BY 
    pd.ViewCount DESC,
    pd.UpVotes DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
