WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(c.UserDisplayName, u.DisplayName) AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS rn,
        p.Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, OwnerDisplayName, Score, Tags
    FROM 
        RankedPosts
    WHERE 
        rn = 1
),
VotesSummary AS (
    SELECT 
        PostId, 
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostStats AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.OwnerDisplayName,
        COALESCE(vs.UpVotes, 0) - COALESCE(vs.DownVotes, 0) AS NetScore,
        tp.Tags
    FROM 
        TopPosts tp
    LEFT JOIN 
        VotesSummary vs ON tp.PostId = vs.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.OwnerDisplayName,
    ps.NetScore,
    AVG(CASE WHEN c.Text IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY ps.PostId) AS CommentPresenceRate,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList
FROM 
    PostStats ps
LEFT JOIN 
    Posts p ON ps.PostId = p.Id
LEFT JOIN 
    LATERAL (
        SELECT 
            UNNEST(string_to_array(p.Tags, '><')) AS TagName
    ) t ON TRUE
LEFT JOIN 
    Comments c ON ps.PostId = c.PostId
GROUP BY 
    ps.PostId, ps.Title, ps.CreationDate, ps.OwnerDisplayName, ps.NetScore
ORDER BY 
    ps.NetScore DESC
LIMIT 10;
