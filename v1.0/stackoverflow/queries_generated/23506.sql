WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(c.CommentCount, 0) AS TotalComments,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVoteCount,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
AggregatedPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        TotalComments,
        PostRank,
        UpVoteCount,
        DownVoteCount,
        CASE 
            WHEN UpVoteCount > DownVoteCount THEN 'Positive'
            WHEN UpVoteCount < DownVoteCount THEN 'Negative'
            ELSE 'Neutral'
        END AS Sentiment
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5
    ORDER BY 
        TotalBadges DESC
),
PopularPosts AS (
    SELECT 
        ap.PostId,
        ap.Title,
        ap.Score,
        ap.TotalComments,
        ap.Sentiment,
        ROW_NUMBER() OVER (ORDER BY ap.Score DESC, ap.TotalComments DESC) AS Rank
    FROM 
        AggregatedPosts ap
    WHERE 
        ap.Score > (SELECT AVG(Score) FROM Posts)
)
SELECT 
    pp.Title,
    pp.Score,
    pp.TotalComments,
    pp.Sentiment,
    tu.DisplayName AS TopUser,
    tu.TotalBadges
FROM 
    PopularPosts pp
LEFT JOIN 
    TopUsers tu ON pp.Sentiment = 'Positive'
WHERE 
    pp.Rank <= 10
ORDER BY 
    pp.Score DESC,
    pp.TotalComments DESC;
