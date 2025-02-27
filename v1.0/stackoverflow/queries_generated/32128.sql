WITH RecursivePostHistory AS (
    SELECT 
        p.Id AS PostId,
        ph.UserId AS EditorId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (4, 5) -- Only title and body edits
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
RecentEdits AS (
    SELECT 
        PostId,
        STRING_AGG(DISTINCT ed.UserDisplayName, ', ') AS Editors,
        MAX(ed.CreationDate) AS LastEdited
    FROM 
        RecursivePostHistory ed
    WHERE 
        ed.EditRank <= 3 -- Get the last three edits for each post
    GROUP BY 
        PostId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.ViewCount,
    p.AnswerCount,
    ue.Reputation AS OwnerReputation,
    us.PostCount AS TotalPostsByOwner,
    us.BadgeCount AS TotalBadgesByOwner,
    us.TotalBounties AS TotalBountyReceived,
    re.Editors,
    re.LastEdited
FROM 
    Posts p
LEFT JOIN 
    Users ue ON p.OwnerUserId = ue.Id
LEFT JOIN 
    UserStats us ON us.UserId = ue.Id
LEFT JOIN 
    RecentEdits re ON p.Id = re.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '30 days'
    AND p.ViewCount > 100
    AND (p.AnswerCount > 0 OR p.AcceptedAnswerId IS NOT NULL)
ORDER BY 
    p.ViewCount DESC
LIMIT 50;
