WITH UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(vote_count), 0) AS TotalVotes,
        COALESCE(SUM(v.Score), 0) AS TotalPostScore,
        RANK() OVER (ORDER BY COALESCE(SUM(vote_count), 0) DESC) AS VoteRank,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS vote_count
        FROM 
            Votes 
        GROUP BY 
            UserId
    ) v ON u.Id = v.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.PostTypeId,
        p.AcceptedAnswerId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM 
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.PostTypeId, p.AcceptedAnswerId
),
RankedPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.Score,
        pd.ViewCount,
        pd.CreationDate,
        pd.PostTypeId,
        pd.AcceptedAnswerId,
        pd.CommentCount,
        pd.HistoryCount,
        ROW_NUMBER() OVER (ORDER BY pd.LastHistoryDate DESC, pd.Score DESC) AS PopularityRank
    FROM 
        PostDetails pd
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalVotes,
    us.TotalPostScore,
    rp.PostId,
    rp.Title AS PostTitle,
    rp.Score AS PostScore,
    rp.ViewCount AS PostViews,
    rp.CommentCount AS TotalComments,
    rp.PopularityRank AS Popularity,
    CASE 
        WHEN rp.AcceptedAnswerId IS NULL THEN 'No Accepted Answer'
        ELSE 'Has Accepted Answer'
    END AS AnswerStatus
FROM 
    UserScores us
LEFT JOIN RankedPosts rp ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
WHERE 
    us.TotalVotes > 10
    AND us.Reputation BETWEEN 100 AND 1000
    AND EXISTS (
        SELECT 1
        FROM Votes v
        WHERE v.UserId = us.UserId
        AND v.VoteTypeId IN (2, 3) -- UpMod or DownMod
    )
ORDER BY 
    us.TotalVotes DESC, us.Reputation DESC, rp.PopularityRank;
