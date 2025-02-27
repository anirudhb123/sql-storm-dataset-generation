WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore,
        COALESCE(u.DisplayName, 'Community') AS OwnerName,
        STRING_AGG(t.TagName, ', ') AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        LATERAL (
            SELECT 
                t.TagName 
            FROM 
                Tags t 
            WHERE 
                t.Id IN (SELECT UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '>'))::int)) 
        ) AS t ON TRUE
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.AnswerCount, u.DisplayName, p.CreationDate, p.OwnerUserId
),

PostVoteStats AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes,
        (SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END)) AS NetScore
    FROM 
        Votes
    GROUP BY 
        PostId
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId, ph.CreationDate
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerName,
    rp.RankScore,
    rp.Score,
    COALESCE(pvs.UpVotes, 0) AS UpVotes,
    COALESCE(pvs.DownVotes, 0) AS DownVotes,
    COALESCE(pvs.TotalVotes, 0) AS TotalVotes,
    COALESCE(pvs.NetScore, 0) AS NetScore,
    rp.TagsList,
    COALESCE(cp.ClosedDate, 'Not Closed') AS ClosedDate,
    COALESCE(cp.CloseReasons, 'No Reasons') AS CloseReasons
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteStats pvs ON rp.PostId = pvs.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    (rp.RankScore <= 5 OR rp.Score > 50) 
    AND (rp.OwnerUserId IS NOT NULL OR rp.OwnerUserId = -1) 
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;
