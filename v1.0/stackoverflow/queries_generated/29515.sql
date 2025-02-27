WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- Within the last year
),
PostTags AS (
    SELECT 
        pt.PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        PostsTags pt
    JOIN 
        Tags t ON pt.TagId = t.Id
    GROUP BY 
        pt.PostId
),
PostVotes AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Body,
    rp.ViewCount,
    COALESCE(pv.UpVotes, 0) AS UpVotes,
    COALESCE(pv.DownVotes, 0) AS DownVotes,
    rp.Score,
    rp.OwnerDisplayName,
    rp.Reputation,
    pt.Tags
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVotes pv ON rp.PostId = pv.PostId
LEFT JOIN 
    PostTags pt ON rp.PostId = pt.PostId
WHERE 
    rp.PostRank = 1 -- Get only the latest question for each user
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC -- Order by score and view count
LIMIT 10; -- Limit the results to the top 10
