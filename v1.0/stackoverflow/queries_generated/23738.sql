WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Id ORDER BY p.CreationDate DESC) AS rn,
        COUNT(*) OVER (PARTITION BY pt.Id) AS post_count,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Tags t ON t.Id IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))::int)
    GROUP BY 
        p.Id
),

PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 19 THEN 1 END) AS ProtectedCount,
        COUNT(*) AS TotalHistoryCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),

UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        MAX(u.Reputation) AS MaxReputation,
        MIN(u.Reputation) AS MinReputation,
        AVG(u.Reputation) AS AvgReputation,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    GROUP BY 
        u.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Tags,
    pH.CloseCount,
    pH.ReopenCount,
    u.UserId,
    u.MaxReputation,
    u.MinReputation,
    u.AvgReputation,
    u.TotalUpVotes,
    u.TotalDownVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryStats pH ON rp.PostId = pH.PostId
JOIN 
    Users u ON u.Id = rp.OwnerUserId
WHERE 
    rp.rn = 1
    AND rp.Score IS NOT NULL
    AND (pH.TotalHistoryCount > 0 OR pH.CloseCount IS NULL)
ORDER BY 
    rp.CreationDate DESC,
    rp.Score DESC
LIMIT 100;

