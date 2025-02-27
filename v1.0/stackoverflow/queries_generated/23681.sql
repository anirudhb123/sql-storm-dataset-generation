WITH RecursivePostStats AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) - COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        p.Id,
        p.Title,
        rps.UpVotes,
        rps.DownVotes,
        rps.CommentCount,
        CASE 
            WHEN rps.UserPostRank <= 5 THEN 'Top Performer'
            WHEN rps.UserPostRank BETWEEN 6 AND 10 THEN 'Moderate Performer'
            ELSE 'Needs Improvement'
        END AS PerformanceCategory
    FROM 
        Posts p
    JOIN 
        RecursivePostStats rps ON p.Id = rps.PostId
)
SELECT 
    tp.Title,
    tp.UpVotes,
    tp.DownVotes,
    tp.CommentCount,
    tp.PerformanceCategory,
    t.TagName,
    STRING_AGG(DISTINCT c.Text, '; ') AS CommentsText,
    COALESCE(MAX(B.Date), 'No Badge') AS LastBadgeDate
FROM 
    TopPosts tp
LEFT JOIN 
    Posts p ON tp.Id = p.Id
LEFT JOIN 
    Tags t ON p.Tags LIKE '%' || t.TagName || '%'
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Badges B ON tp.Id = B.UserId
WHERE 
    tp.UpVotes > 0 OR tp.CommentCount > 0
GROUP BY 
    tp.Title, tp.UpVotes, tp.DownVotes, tp.CommentCount, tp.PerformanceCategory, t.TagName
ORDER BY 
    tp.UpVotes DESC, tp.CommentCount DESC, tp.PerformanceCategory;
