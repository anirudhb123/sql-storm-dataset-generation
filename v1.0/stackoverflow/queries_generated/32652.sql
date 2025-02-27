-- Performance Benchmarking SQL Query
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- focused on recent posts
    GROUP BY 
        p.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(u.UpVotes - u.DownVotes) AS NetVotes,
        DENSE_RANK() OVER (ORDER BY SUM(u.UpVotes - u.DownVotes) DESC) AS UserRank
    FROM 
        Users u
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(u.UpVotes - u.DownVotes) > 10 -- Only considering active users
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    CROSS JOIN 
        UNNEST(string_to_array(p.Tags, ',', 1)) AS tag
    JOIN 
        Tags t ON tag::varchar = t.TagName
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.Rank,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    tu.DisplayName AS TopUser,
    tu.NetVotes,
    pt.Tags
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.Id
LEFT JOIN 
    PostTags pt ON rp.PostId = pt.PostId
WHERE 
    rp.Rank <= 5 -- only top 5 posts per user
ORDER BY 
    rp.Score DESC, 
    CloseCount DESC;
