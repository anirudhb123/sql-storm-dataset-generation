WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
UserDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreateDate,
        (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id) AS BadgeCount
    FROM 
        Users u
),
VoteStatistics AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(CONCAT(pt.Name, ' on ', TO_CHAR(ph.CreationDate, 'YYYY-MM-DD HH24:MI:SS')), ', ') AS History
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    ud.UserId,
    ud.DisplayName,
    ud.Reputation,
    COALESCE(rp.PostId, 0) AS TopQuestionId,
    COALESCE(rp.Title, 'No Questions') AS TopQuestionTitle,
    COALESCE(rp.CreationDate, '1970-01-01') AS TopQuestionDate,
    COALESCE(rp.ViewCount, 0) AS TopQuestionViews,
    COALESCE(rp.Score, -1) AS TopQuestionScore,
    COALESCE(vs.UpVotes, 0) AS TotalUpVotes,
    COALESCE(vs.DownVotes, 0) AS TotalDownVotes,
    COALESCE(phd.History, 'No History') AS PostHistory 
FROM 
    UserDetails ud
LEFT JOIN 
    RankedPosts rp ON ud.UserId = rp.OwnerUserId AND rp.Rank = 1
LEFT JOIN 
    VoteStatistics vs ON rp.PostId = vs.PostId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    ud.Reputation > (SELECT AVG(Reputation) FROM Users) -- Users above average reputation
ORDER BY 
    ud.Reputation DESC
LIMIT 50
OFFSET 0; -- Take the top 50
