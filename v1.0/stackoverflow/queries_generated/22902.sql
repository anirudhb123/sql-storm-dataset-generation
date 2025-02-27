WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore,
        COUNT(a.Id) OVER (PARTITION BY p.OwnerUserId) AS AnswerCount,
        SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownVoteCount,
        COALESCE(
            (SELECT ph.CreationDate 
             FROM PostHistory ph 
             WHERE ph.PostId = p.Id 
             AND ph.PostHistoryTypeId IN (10, 11) 
             ORDER BY ph.CreationDate DESC 
             LIMIT 1), 
            '1970-01-01'::timestamp
        ) AS LastClosedReopenedDate
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 AND  -- Only questions
        p.CreationDate < NOW() - INTERVAL '6 months'  -- Questions older than 6 months
),
PostTotals AS (
    SELECT 
        rp.OwnerUserId,
        COUNT(rp.PostId) AS TotalPosts,
        SUM(rp.UpVoteCount) AS TotalUpVotes,
        SUM(rp.DownVoteCount) AS TotalDownVotes,
        AVG(rp.AnswerCount) AS AvgAnswersPerPost 
    FROM 
        RankedPosts rp
    GROUP BY 
        rp.OwnerUserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    pt.TotalPosts,
    pt.TotalUpVotes,
    pt.TotalDownVotes,
    pt.AvgAnswersPerPost,
    p.Title,
    p.CreationDate,
    p.LastClosedReopenedDate,
    CASE 
        WHEN pt.TotalUpVotes IS NULL OR pt.TotalPosts = 0 THEN 0 
        ELSE ROUND((pt.TotalUpVotes::float / (pt.TotalPosts + 1)) * 100, 2) 
    END AS UpVotePercentage
FROM 
    Users u
JOIN 
    PostTotals pt ON u.Id = pt.OwnerUserId
JOIN 
    RankedPosts p ON p.OwnerUserId = u.Id
WHERE 
    p.RankScore = 1  -- Select highest scored post for each user
ORDER BY 
    UpVotePercentage DESC NULLS LAST, 
    pt.TotalPosts DESC, 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
