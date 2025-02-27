WITH RecursiveTagHistory AS (
    SELECT 
        p.Id AS PostId,
        t.TagName,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%' 
    WHERE 
        p.PostTypeId = 1 
        AND ph.PostHistoryTypeId IN (3, 6)  -- Considering initial and edited tags
),
TagDetails AS (
    SELECT 
        PostId,
        TagName,
        CreationDate,
        rn
    FROM 
        RecursiveTagHistory
    WHERE 
        rn <= 3  -- Get the last 3 tag edits for each post
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountySpent,
        SUM(COALESCE(v.Id, 0)) AS UpVotesGiven
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(v.CreationDate IS NOT NULL), 0) AS VoteCount,
        COUNT(c.Id) AS CommentCount,
        SUM(ph.PostHistoryTypeId = 10) AS CloseVotes 
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days' 
    GROUP BY 
        p.Id
)
SELECT 
    uda.UserId,
    uda.DisplayName,
    uda.PostsCount,
    uda.TotalBountySpent,
    uda.UpVotesGiven,
    rpa.PostId,
    rpa.Title,
    rpa.CreationDate,
    rpa.VoteCount,
    rpa.CommentCount,
    rpa.CloseVotes,
    STRING_AGG(td.TagName, ', ') AS Tags
FROM 
    UserActivity uda
JOIN 
    RecentPostActivity rpa ON rpa.PostId IN (
        SELECT PostId FROM Tags t 
        JOIN TagDetails td ON t.TagName = td.TagName
    )
LEFT JOIN 
    TagDetails td ON rpa.PostId = td.PostId
GROUP BY 
    uda.UserId, uda.DisplayName, rpa.PostId, rpa.Title, rpa.CreationDate, 
    rpa.VoteCount, rpa.CommentCount, rpa.CloseVotes
ORDER BY 
    uda.TotalBountySpent DESC,
    rpa.VoteCount DESC;
