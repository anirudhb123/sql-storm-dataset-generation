WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TagDetails AS (
    SELECT 
        pt.Id AS PostTypeId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS UpVotesCount,
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS DownVotesCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount
    FROM 
        PostTypes pt
    LEFT JOIN 
        Posts p ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    GROUP BY 
        pt.Id
),
PostWithTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COALESCE(c.Comment, 'No comments') AS LatestComment
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        LATERAL string_to_array(p.Tags, ',') AS t(TagName) ON TRUE
    GROUP BY 
        p.Id, c.Comment
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    td.PostCount,
    td.UpVotesCount,
    td.DownVotesCount,
    pt.Id AS PostTypeId,
    pt.Name AS PostTypeName,
    pwt.Tags,
    pwt.LatestComment,
    CASE 
        WHEN td.UpVotesCount IS NULL THEN 'No votes'
        WHEN td.UpVotesCount > td.DownVotesCount THEN 'Positive'
        ELSE 'Negative'
    END AS VoteSentiment
FROM 
    RankedPosts rp
JOIN 
    TagDetails td ON rp.PostId = td.PostTypeId
JOIN 
    PostTypes pt ON rp.PostId = pt.Id
JOIN 
    PostWithTags pwt ON rp.PostId = pwt.PostId
WHERE 
    rp.Rank <= 5 
    AND (td.UpVotesCount <> td.DownVotesCount OR td.PostCount IS NULL)
ORDER BY 
    rp.ViewCount DESC
LIMIT 50;

-- Additionally, to explore corner cases and obscure semantics:
SELECT
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM Votes v 
            WHERE v.PostId = p.Id AND v.VoteTypeId IN (2, 3)
        ) THEN 'Has Votes'
        ELSE 'No Votes'
    END AS VoteStatus,
    COUNT(DISTINCT c.Id) NULLIF(COUNT(c.Id), 0) AS CommentCount,
    COALESCE(b.Name, 'No Badges') AS BadgeName
FROM 
    Posts p
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    Badges b ON b.UserId = p.OwnerUserId
WHERE 
    p.ViewCount > 100 AND 
    (p.AcceptedAnswerId IS NOT NULL OR p.ParentId IS NULL)
GROUP BY 
    p.Id
HAVING 
    COUNT(c.Id) > 0 
    AND COUNT(DISTINCT b.Name) > 1
ORDER BY
    p.ViewCount DESC
LIMIT 100;
