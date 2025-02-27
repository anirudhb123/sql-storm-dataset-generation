WITH PostsWithVotes AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score,
        p.OwnerUserId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes, 
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate BETWEEN '2020-01-01' AND '2023-01-01'
    GROUP BY 
        p.Id, p.Title, p.Score, p.OwnerUserId
),

RecentUserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN p.OwnerUserId = u.Id THEN 1 ELSE 0 END), 0) AS CreatedPosts,
        COALESCE(SUM(CASE WHEN ph.UserId = u.Id THEN 1 ELSE 0 END), 0) AS EditHistory,
        RANK() OVER (ORDER BY COALESCE(SUM(CASE WHEN p.OwnerUserId = u.Id THEN 1 ELSE 0 END), 0) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        u.Id, u.DisplayName
),

VoteSummary AS (
    SELECT 
        PostId,
        COALESCE(SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)

SELECT 
    p.PostId,
    p.Title,
    COALESCE(vs.TotalUpVotes, 0) AS TotalUpVotes,
    COALESCE(vs.TotalDownVotes, 0) AS TotalDownVotes,
    u.DisplayName AS PostOwner,
    ra.CreatedPosts,
    ra.EditHistory,
    CASE 
        WHEN ra.UserRank IS NOT NULL AND ra.UserRank <= 10 THEN 'Top User'
        ELSE 'Regular User'
    END AS UserStatus
FROM 
    PostsWithVotes p
LEFT JOIN 
    VoteSummary vs ON p.PostId = vs.PostId
LEFT JOIN 
    RecentUserActivity ra ON p.OwnerUserId = ra.UserId
WHERE 
    p.Rank <= 5 -- Top 5 posts by score in their category
ORDER BY 
    p.Score DESC, 
    p.Title ASC;

-- Additional corner case handle
WITH DuplicateCheck AS (
    SELECT 
        PostId,
        COUNT(DISTINCT RelatedPostId) AS DuplicateCount
    FROM 
        PostLinks
    GROUP BY 
        PostId
    HAVING 
        COUNT(DISTINCT RelatedPostId) > 1
)

SELECT 
    p.*,
    COALESCE(dc.DuplicateCount, 0) AS IsDuplicate,
    CASE 
        WHEN dc.DuplicateCount > 0 THEN 'This post has duplicates'
        ELSE 'This post is unique'
    END AS DuplicationStatus
FROM 
    Posts p
LEFT JOIN 
    DuplicateCheck dc ON p.Id = dc.PostId
WHERE 
    p.AcceptedAnswerId IS NOT NULL
    AND (p.LastActivityDate IS NOT NULL OR p.ClosedDate IS NOT NULL)
    AND NOT EXISTS (
        SELECT 1 
        FROM Posts p2 
        WHERE p2.Id = p.AcceptedAnswerId AND p2.OwnerUserId IS NOT NULL
    )
ORDER BY 
    p.CreationDate DESC;
