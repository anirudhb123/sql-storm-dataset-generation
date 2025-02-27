WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) -- Considering only Questions and Answers
), 
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
), 
PostLinksAnalysis AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS RelatedPostCount,
        STRING_AGG(DISTINCT pl.RelatedPostId::text, ', ') AS RelatedPostIds
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    COALESCE(pla.RelatedPostCount, 0) AS RelatedCount,
    COALESCE(ua.PostsCreated, 0) AS TotalPostsByUser,
    COALESCE(ua.UpVotesReceived, 0) AS TotalUpVotes,
    COALESCE(ua.DownVotesReceived, 0) AS TotalDownVotes,
    COALESCE(ua.TotalBounty, 0) AS TotalBountyReceived
FROM 
    RankedPosts r
LEFT JOIN 
    PostLinksAnalysis pla ON r.PostId = pla.PostId
LEFT JOIN 
    Users u ON r.PostId IN (SELECT AcceptedAnswerId FROM Posts WHERE PostTypeId = 1)
LEFT JOIN 
    UserActivity ua ON u.Id = r.OwnerUserId 
WHERE 
    r.Rank <= 5 -- Top 5 posts per type
ORDER BY 
    r.Score DESC, r.CreationDate DESC;
