WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'UpMod') AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'DownMod') AS DownVoteCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    LEFT JOIN 
        string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS tag ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName ILIKE '%' || tag || '%'
    WHERE 
        p.Score > 0
    GROUP BY 
        p.Id, u.DisplayName, pt.Name
),
AggregatedResults AS (
    SELECT 
        Rank,
        COUNT(PostId) AS PostCount,
        SUM(ViewCount) AS TotalViews,
        AVG(UpVoteCount) AS AvgUpVotes,
        AVG(DownVoteCount) AS AvgDownVotes
    FROM 
        RankedPosts
    GROUP BY 
        Rank
)
SELECT 
    ar.Rank,
    ar.PostCount,
    ar.TotalViews,
    ar.AvgUpVotes,
    ar.AvgDownVotes,
    p.Title,
    p.OwnerDisplayName
FROM 
    AggregatedResults ar
JOIN 
    RankedPosts p ON ar.Rank = p.Rank
ORDER BY 
    ar.Rank, ar.PostCount DESC;
