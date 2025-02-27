WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.Visibility = 'visible' -- Assuming there is a visibility field to filter out deleted or hidden posts
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS TagList
    FROM 
        Posts p
    JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '>')::int[])
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    u.DisplayName AS Owner,
    rp.Score,
    rp.ViewCount,
    pt.TagList,
    ua.VoteCount,
    ua.UpVotes,
    ua.DownVotes,
    ua.CommentCount
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserActivity ua ON u.Id = ua.UserId
JOIN 
    PostTags pt ON rp.PostId = pt.PostId
WHERE 
    rp.Rank <= 5  -- Top 5 ranked posts per tag
ORDER BY 
    pt.TagList, rp.Score DESC;
