WITH RecursivePostCTE AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.OwnerUserId, 
        p.CreationDate, 
        p.Score, 
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Selecting only questions
    UNION ALL
    SELECT 
        p.Id, 
        p.Title, 
        p.OwnerUserId, 
        p.CreationDate, 
        p.Score, 
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE r ON p.ParentId = r.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerName,
        p.CreationDate,
        p.Score,
        COALESCE(
            (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0
        ) AS CommentCount,
        COALESCE(
            (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0
        ) AS UpVoteCount,
        COALESCE(
            (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0
        ) AS DownVoteCount,
        u.Reputation,
        TotalBounty
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UserReputation ur ON u.Id = ur.UserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
FinalResults AS (
    SELECT 
        pa.*, 
        COUNT(DISTINCT r.Id) AS RelatedPostsCount,
        ROW_NUMBER() OVER (PARTITION BY pa.UserId ORDER BY pa.Score DESC) AS UserPostRank
    FROM 
        PostAnalytics pa
    LEFT JOIN 
        RecursivePostCTE r ON pa.PostId = r.Id
    GROUP BY 
        pa.PostId, pa.Title, pa.OwnerName, pa.CreationDate, pa.Score, 
        pa.CommentCount, pa.UpVoteCount, pa.DownVoteCount, 
        pa.Reputation, pa.TotalBounty
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.OwnerName,
    fr.CreationDate,
    fr.Score,
    fr.CommentCount,
    fr.UpVoteCount,
    fr.DownVoteCount,
    fr.Reputation,
    fr.TotalBounty,
    fr.RelatedPostsCount,
    fr.UserPostRank
FROM 
    FinalResults fr
WHERE 
    fr.UserPostRank <= 5  -- Get top 5 posts for each user based on Score
ORDER BY 
    fr.Score DESC, fr.CreationDate;
