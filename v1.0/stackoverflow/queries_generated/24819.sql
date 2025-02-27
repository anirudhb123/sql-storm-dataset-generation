WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId
),
PoissonDistribution AS (
    SELECT
        Level,
        EXP(-(ScoreSum / NULLIF(Sessions, 0))) * POWER((ScoreSum / NULLIF(Sessions, 0)), Level) / FACTORIAL(Level) AS Probability
    FROM (
        SELECT 
            p.OwnerUserId,
            COUNT(DISTINCT p.Id) AS Sessions,
            SUM(p.Score) AS ScoreSum,
            ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY SUM(p.Score) DESC) AS Level
        FROM 
            Posts p
        GROUP BY 
            p.OwnerUserId
    ) AS Summarized
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT hp.PostId) AS HistoricalPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistory hp ON p.Id = hp.PostId
    WHERE 
        u.Reputation >= 1000
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT hp.Id) > 0
)
SELECT 
    up.DisplayName,
    SUM(rp.CommentCount) AS TotalComments,
    SUM(rp.UpVotes) AS TotalUpVotes,
    SUM(rp.DownVotes) AS TotalDownVotes,
    MAX(rp.Rank) AS HighestRank,
    td.TotalScore,
    COALESCE(pds.Probability, 0) AS PoissonProbability
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
LEFT JOIN 
    TopUsers td ON up.Id = td.UserId
LEFT JOIN 
    PoissonDistribution pds ON up.Id = pds.OwnerUserId
WHERE 
    rp.Rank <= 5
GROUP BY 
    up.DisplayName, td.TotalScore, pds.Probability
ORDER BY 
    TotalComments DESC, TotalUpVotes DESC;
