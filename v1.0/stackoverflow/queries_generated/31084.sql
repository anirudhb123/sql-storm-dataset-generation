WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only consider questions
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  -- BountyStart and BountyClose
    GROUP BY 
        u.Id, u.Reputation
),
PostHistoryWithComments AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        ph.Text,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CommentRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12)  -- Only relevant post history types: close, reopen, delete
),
FlaggedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        u.UserId,
        u.Reputation,
        u.QuestionCount,
        u.TotalBounty,
        COALESCE(phwc.Comment, 'No Comments') AS LastHistoryComment,
        COALESCE(phwc.Text, 'No Text') AS LastHistoryText
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation u ON rp.PostId = u.UserId
    LEFT JOIN 
        PostHistoryWithComments phwc ON rp.PostId = phwc.PostId AND phwc.CommentRank = 1
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.Reputation,
    fp.QuestionCount,
    fp.TotalBounty,
    fp.LastHistoryComment,
    fp.LastHistoryText
FROM 
    FlaggedPosts fp
WHERE 
    fp.Score < 0 AND fp.Reputation < 100  -- Filtering on negative score and low reputation
ORDER BY 
    fp.Score ASC, fp.ViewCount DESC;

WITH RECURSIVE VotesAggregation AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    a.PostId,
    a.TotalVotes,
    a.UpVotes,
    a.DownVotes, 
    CASE 
        WHEN a.TotalVotes > 0 THEN 
            CONCAT('Votes - Up: ', a.UpVotes, ', Down: ', a.DownVotes)
        ELSE 'No Votes'
    END AS VoteSummary
FROM 
    VotesAggregation a
WHERE 
    a.TotalVotes > 10;  -- Only consider posts with more than 10 total votes
