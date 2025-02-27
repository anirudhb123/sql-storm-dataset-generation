WITH RankedUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END) AS NetVotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, u.DisplayName
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.ViewCount,
    pd.Score,
    pd.CreationDate,
    pd.OwnerDisplayName,
    pd.CommentCount,
    COALESCE(cph.LastClosedDate, 'No Close History'::timestamp) AS LastClosedDate,
    COALESCE(cph.CloseCount, 0) AS CloseCount,
    ru.UserRank
FROM 
    PostDetails pd
LEFT JOIN 
    ClosedPostHistory cph ON pd.PostId = cph.PostId
JOIN 
    RankedUsers ru ON pd.OwnerDisplayName = ru.DisplayName
WHERE 
    pd.ViewCount > 100
    AND pd.Score > 0
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC
LIMIT 50;

WITH tag_summary AS (
    SELECT 
        unnest(string_to_array(Tags, '>')) AS Tag
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
), 
tag_count AS (
    SELECT 
        Tag, COUNT(*) AS TagCount
    FROM 
        tag_summary
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 10
)
SELECT 
    tc.Tag,
    tc.TagCount
FROM 
    tag_count tc
ORDER BY 
    tc.TagCount DESC;
