WITH PostTagStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Tags,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(SUM(v.VoteTypeId = 2)::int, 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3)::int, 0) AS DownVotes,
        COALESCE(pt.Name, 'No Tags') AS TagName,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Tags t ON t.TagName = ANY(string_to_array(TRIM(BOTH '<>' FROM REPLACE(p.Tags, '><', '>')), '>'))
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11) -- Filter for close/reopen history
    LEFT JOIN 
        PostHistoryTypes pt ON pt.Id = ph.PostHistoryTypeId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Tags, pt.Name
),
Ranking AS (
    SELECT
        PostId,
        Title,
        CreationDate,
        OwnerUserId,
        Tags,
        ViewCount,
        AnswerCount,
        UpVotes,
        DownVotes,
        TagName,
        CommentCount,
        RANK() OVER (ORDER BY (ViewCount + UpVotes - DownVotes) DESC) AS PostRanking -- Post ranking logic by views and votes
    FROM 
        PostTagStats
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.OwnerUserId,
    r.Tags,
    r.ViewCount,
    r.AnswerCount,
    r.UpVotes,
    r.DownVotes,
    r.TagName,
    r.CommentCount,
    r.PostRanking,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(DISTINCT b.Id) AS BadgeCount -- Count the badges for each post owner
FROM 
    Ranking r
JOIN 
    Users u ON u.Id = r.OwnerUserId
LEFT JOIN 
    Badges b ON b.UserId = u.Id
GROUP BY 
    r.PostId, r.Title, r.CreationDate, r.OwnerUserId, r.Tags, r.ViewCount, r.AnswerCount, 
    r.UpVotes, r.DownVotes, r.TagName, r.CommentCount, r.PostRanking, u.DisplayName, u.Reputation
ORDER BY 
    r.PostRanking
LIMIT 10; -- Limit to top 10 posts
