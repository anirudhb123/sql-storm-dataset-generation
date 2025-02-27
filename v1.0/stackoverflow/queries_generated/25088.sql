WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Considering Questions only
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.Tags, u.DisplayName
), 
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.UserId IS NOT NULL) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostTagCounts AS (
    SELECT 
        unnest(string_to_array(p.Tags, '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Considering Questions only
    GROUP BY 
        Tag
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.Tags,
    rp.OwnerDisplayName,
    rp.CommentCount,
    ua.DisplayName AS UserDisplayName,
    ua.TotalVotes,
    ua.UpVotes,
    ua.DownVotes,
    pt.Tag,
    pt.PostCount
FROM 
    RankedPosts rp
JOIN 
    UserActivity ua ON rp.OwnerUserId = ua.UserId
JOIN 
    PostTagCounts pt ON pt.Tag = ANY (string_to_array(rp.Tags, '><'))
WHERE 
    rp.Rank <= 5 -- Retrieve top 5 ranked posts per user
ORDER BY 
    rp.ViewCount DESC, 
    rp.Score DESC;
