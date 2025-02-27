WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'UpMod') AS UpVotes,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'DownMod') AS DownVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) - 
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS VoteBalance
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        VoteTypes vt ON vt.Id = v.VoteTypeId
    GROUP BY 
        u.Id, u.DisplayName
), 
FrequentTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 5
), 
PostAggregates AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        ARRAY_AGG(DISTINCT t.TagName) AS AssociatedTags,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.VoteTypeId = 9
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        p.Id, p.Title, p.CreationDate
), 
ClosedPostChanges AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosed
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) -- Closed, Reopened, Deleted
    GROUP BY 
        ph.PostId
)
SELECT 
    pa.Id AS PostId,
    pa.Title,
    pa.CreationDate,
    pa.TotalBounty,
    pa.CommentCount,
    COALESCE(pr.LastClosed, 'No Closure') AS LastClosureDate,
    CASE 
        WHEN pa.CommentCount > 5 THEN 'Popular Post' 
        ELSE 'Regular Post' 
    END AS PostClassification,
    ARRAY_AGG(DISTINCT ut.DisplayName) AS ActiveUsers,
    (
        SELECT STRING_AGG(DISTINCT f.TagName, ', ') 
        FROM FrequentTags f 
        WHERE f.PostCount > 0
    ) AS FrequentTags
FROM 
    PostAggregates pa
LEFT JOIN 
    ClosedPostChanges pr ON pa.Id = pr.PostId
LEFT JOIN 
    UserVoteStats ut ON ut.VoteBalance >= 5 -- Users with a positive vote balance
WHERE 
    pa.UserRank = 1 -- Selecting only the top-ranked user for each post
GROUP BY 
    pa.Id, pa.Title, pa.CreationDate, pa.TotalBounty, pa.CommentCount, pr.LastClosed
ORDER BY 
    pa.TotalBounty DESC, pa.CommentCount DESC;
