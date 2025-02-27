WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL string_to_array(p.Tags, '>') AS t(TagName) ON TRUE
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, p.AcceptedAnswerId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(up.UpVotes) AS TotalUpVotes,
        SUM(up.DownVotes) AS TotalDownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        (SELECT 
            UserId, 
            Count(*) FILTER (WHERE VoteTypeId = 2) AS UpVotes,
            Count(*) FILTER (WHERE VoteTypeId = 3) AS DownVotes
        FROM 
            Votes 
        GROUP BY 
            UserId) up ON u.Id = up.UserId 
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(Tags, '>')) AS Tag,
        COUNT(*) AS UsageCount
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        unnest(string_to_array(Tags, '>'))
    ORDER BY 
        UsageCount DESC
    LIMIT 10
)
SELECT 
    p.Title AS PostTitle,
    p.ViewCount,
    p.Score,
    u.DisplayName AS Author,
    u.TotalPosts,
    bt.Tag AS PopularTag,
    r.PostRank
FROM 
    RankedPosts r
JOIN 
    Users u ON r.AcceptedAnswerId = u.Id
JOIN 
    PopularTags bt ON bt.Tag = ANY(r.Tags)
WHERE 
    r.PostRank <= 5
ORDER BY 
    r.Score DESC, 
    p.ViewCount DESC;
