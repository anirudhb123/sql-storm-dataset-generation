WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(CAST(AVG(v.BountyAmount) AS DECIMAL(10, 2)), 0) AS AverageBounty,
        (SELECT COUNT(*) FROM Votes v2 WHERE v2.PostId = p.Id AND v2.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v3 WHERE v3.PostId = p.Id AND v3.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
),
PostHistoryWithCloseReasons AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        json_agg(pt.Name) AS CloseReasonNames
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes pt ON ph.Comment::int = pt.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Only closed or reopened posts
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, ph.CreationDate
)
SELECT 
    r.PostId,
    r.Title,
    r.Score,
    r.ViewCount,
    r.CreationDate,
    r.RankByScore,
    r.CommentCount,
    r.AverageBounty,
    r.UpVoteCount,
    r.DownVoteCount,
    CASE 
        WHEN r.RankByScore = 1 THEN 'Top post by user'
        WHEN r.RankByScore <= 5 THEN 'High-ranking post'
        ELSE 'Regular post'
    END AS PostRankStatus,
    COALESCE(p.CloseReasonNames, 'No close reasons') AS CloseReasonDetails,
    CASE 
        WHEN r.AcceptedAnswerId IS NOT NULL THEN 'Accepted Answer Exists'
        ELSE 'No Accepted Answer'
    END AS AnswerStatus,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    RankedPosts r
LEFT JOIN 
    PostHistoryWithCloseReasons p ON r.PostId = p.PostId
LEFT JOIN 
    Posts p2 ON r.PostId = p2.Id
LEFT JOIN 
    LATERAL (SELECT * FROM unnest(string_to_array(p2.Tags, '>')) AS t(TagName)) AS t ON TRUE
WHERE 
    r.CommentCount > 0 OR r.UpVoteCount > 0
GROUP BY 
    r.PostId, r.Title, r.Score, r.ViewCount, r.CreationDate, r.RankByScore, r.CommentCount, r.AverageBounty, r.UpVoteCount, r.DownVoteCount, p.CloseReasonNames
ORDER BY 
    r.ViewCount DESC, r.Score DESC
LIMIT 100;
