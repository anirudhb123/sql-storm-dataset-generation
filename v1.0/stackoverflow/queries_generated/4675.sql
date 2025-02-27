WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id 
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
), RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '1 month'
    GROUP BY 
        v.PostId
), PostHistories AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    COALESCE(rv.UpVotes, 0) AS UpVotes,
    COALESCE(rv.DownVotes, 0) AS DownVotes,
    rp.CreationDate,
    rp.OwnerDisplayName,
    php.EditCount,
    php.LastEditDate
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentVotes rv ON rp.PostId = rv.PostId
LEFT JOIN 
    PostHistories php ON rp.PostId = php.PostId
WHERE 
    rp.UserRank = 1
ORDER BY 
    rp.ViewCount DESC, 
    rp.CreationDate DESC
LIMIT 50;

-- Subquery to find the most common tags among the top posts
WITH TagCounts AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(p.Tags, '>')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TagName
)
SELECT 
    TagName 
FROM 
    TagCounts 
ORDER BY 
    PostCount DESC 
LIMIT 10;
