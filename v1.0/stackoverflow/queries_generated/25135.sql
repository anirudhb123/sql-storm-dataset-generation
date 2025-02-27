WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        pt.Name AS PostType,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Tags t ON t.Id = ANY (string_to_array(p.Tags, '><')::int[])
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year' -- Gather posts from the last year
    GROUP BY 
        p.Id, pt.Name, p.Body, p.CreationDate, p.LastActivityDate
),
TopPosts AS (
    SELECT 
        rp.*,
        (UpVotes - DownVotes) AS NetVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 -- Get top 5 posts per user
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    json_agg(json_build_object(
        'PostId', tp.PostId,
        'Title', tp.Title,
        'CreationDate', tp.CreationDate,
        'LastActivityDate', tp.LastActivityDate,
        'PostType', tp.PostType,
        'Tags', tp.Tags,
        'CommentCount', tp.CommentCount,
        'NetVotes', tp.NetVotes
    )) AS UserTopPosts
FROM 
    Users u
JOIN 
    TopPosts tp ON u.Id = tp.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    u.Reputation DESC; -- Order users by reputation
