WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        u.DisplayName AS Owner,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(v.VoteTypeId = 2) AS UpvoteCount,  -- Assuming 2 is UpMod
        SUM(v.VoteTypeId = 3) AS DownvoteCount  -- Assuming 3 is DownMod
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.LastActivityDate, u.DisplayName
), RankedPosts AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY LastActivityDate DESC) AS Rank
    FROM 
        FilteredPosts
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Owner,
    r.CommentCount,
    r.VoteCount,
    r.UpvoteCount,
    r.DownvoteCount,
    (r.UpvoteCount - r.DownvoteCount) AS NetScore
FROM 
    RankedPosts r
WHERE 
    r.Rank <= 10
ORDER BY 
    r.NetScore DESC;
