WITH ProcessedTags AS (
    SELECT 
        Id as TagId,
        TagName,
        COUNT(*) as PostCount,
        STRING_AGG(DISTINCT PostId::text, ', ') as AssociatedPosts
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.Id, t.TagName
), PopularUsers AS (
    SELECT 
        u.Id as UserId, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) as TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) as Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) as Answers,
        SUM(v.VoteTypeId = 2) as TotalUpVotes,
        SUM(v.VoteTypeId = 3) as TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5
), RecentActivity AS (
    SELECT 
        post.Title,
        post.Body,
        post.CreationDate,
        COUNT(c.Id) as CommentCount,
        CASE 
            WHEN ph.PostHistoryTypeId = 10 THEN 'Closed'
            WHEN ph.PostHistoryTypeId = 11 THEN 'Reopened'
            ELSE 'Active'
        END as PostStatus,
        STRING_AGG(DISTINCT ph.Comment, ', ') as HistoryComments
    FROM 
        Posts post
    LEFT JOIN 
        Comments c ON c.PostId = post.Id
    LEFT JOIN 
        PostHistory ph ON ph.PostId = post.Id
    WHERE 
        post.LastActivityDate > NOW() - INTERVAL '30 days'
    GROUP BY 
        post.Title, post.Body, post.CreationDate, ph.PostHistoryTypeId
)
SELECT 
    pt.TagId,
    pt.TagName,
    pt.PostCount,
    pt.AssociatedPosts,
    pu.UserId,
    pu.DisplayName,
    pu.TotalPosts,
    pu.Questions,
    pu.Answers,
    pu.TotalUpVotes,
    pu.TotalDownVotes,
    ra.Title,
    ra.Body,
    ra.CreationDate,
    ra.CommentCount,
    ra.PostStatus,
    ra.HistoryComments
FROM 
    ProcessedTags pt
JOIN 
    PopularUsers pu ON pt.PostCount > 10
JOIN 
    RecentActivity ra ON ra.CommentCount > 0
ORDER BY 
    pt.PostCount DESC, pu.TotalUpVotes DESC;
