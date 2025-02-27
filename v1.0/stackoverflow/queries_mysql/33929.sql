
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        @row_number := IF(@prev_owner = p.OwnerUserId, @row_number + 1, 1) AS PostRank,
        @prev_owner := p.OwnerUserId
    FROM 
        Posts p,
        (SELECT @row_number := 0, @prev_owner := NULL) AS vars
    WHERE 
        p.PostTypeId = 1  
    ORDER BY 
        p.OwnerUserId, p.CreationDate DESC
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionsCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1  
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ur.QuestionsCount,
        ur.TotalBounty,
        @dense_rank := IF(@prev_reputation = ur.Reputation, @dense_rank, @dense_rank + 1) AS ReputationRank,
        @prev_reputation := ur.Reputation
    FROM 
        UserReputation ur,
        (SELECT @dense_rank := 0, @prev_reputation := NULL ORDER BY ur.Reputation DESC) AS vars
    WHERE 
        ur.QuestionsCount > 5
),
OpenQuestions AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        c.UserDisplayName AS LastCommenter,
        @row_number_comment := IF(@prev_post = p.Id, @row_number_comment + 1, 1) AS LatestCommentRank,
        @prev_post := p.Id
    FROM 
        Posts p,
        (SELECT @row_number_comment := 0, @prev_post := NULL) AS vars
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND p.ClosedDate IS NULL  
    ORDER BY 
        p.Id, c.CreationDate DESC
),
FinalResults AS (
    SELECT 
        tp.UserId,
        tp.DisplayName,
        tp.Reputation,
        tp.QuestionsCount,
        tp.TotalBounty,
        rq.PostId,
        rq.Title,
        rq.CreationDate,
        rq.Score,
        rq.ViewCount,
        oq.LastCommenter
    FROM 
        TopUsers tp
    JOIN 
        RankedPosts rq ON tp.UserId = rq.OwnerUserId
    LEFT JOIN 
        OpenQuestions oq ON rq.PostId = oq.Id
    WHERE 
        tp.ReputationRank <= 10  
)

SELECT 
    fr.UserId,
    fr.DisplayName,
    fr.Reputation,
    fr.QuestionsCount,
    fr.TotalBounty,
    fr.PostId,
    fr.Title AS PostTitle,
    fr.CreationDate,
    fr.Score,
    fr.ViewCount,
    COALESCE(fr.LastCommenter, 'No comments yet') AS LastCommenter
FROM 
    FinalResults fr
ORDER BY 
    fr.Reputation DESC,
    fr.CreationDate DESC;
