WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) as rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- Bounty Start and Close
    GROUP BY 
        u.Id
),
TopVotedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        LATERAL (SELECT unnest(string_to_array(p.Tags, '><')) AS TagName) t ON TRUE
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
    HAVING 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) > 10 -- More than 10 upvotes
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Body, Tags
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    COALESCE(RP.Title, 'No Questions Posted') AS LastQuestionTitle,
    COALESCE(TPP.Tags, 'No Tags') AS TagsFromMostVoted,
    US.QuestionCount,
    US.TotalBounties,
    RE.CreationDate AS LastEditDate,
    RE.Comment AS LastEditComment
FROM 
    UserStats US
LEFT JOIN 
    RankedPosts RP ON US.UserId = RP.Id AND RP.rn = 1
LEFT JOIN 
    TopVotedPosts TPP ON US.UserId = TPP.Id
LEFT JOIN 
    RecentEdits RE ON US.UserId = RE.UserDisplayName AND RE.EditRank = 1
WHERE 
    US.QuestionCount > 0 
ORDER BY 
    u.Reputation DESC
LIMIT 100;
