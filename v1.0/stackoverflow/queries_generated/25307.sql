WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only considering Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Questions from the last year
),
TopTags AS (
    SELECT 
        UNNEST(string_to_array(LEADING '<>' FROM Tags)) AS TagName,
        COUNT(1) AS TagCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes, -- UpMod
        SUM(v.VoteTypeId = 3) AS DownVotes -- DownMod
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        QuestionCount DESC
    LIMIT 5
)
SELECT 
    ua.DisplayName,
    ua.QuestionCount,
    ua.CommentCount,
    ua.UpVotes,
    ua.DownVotes,
    tt.TagName,
    tt.TagCount
FROM 
    UserActivity ua
JOIN 
    TopTags tt ON tt.TagName = ANY(string_to_array(ua.Tags, ',')) -- Match user tags with top tags
ORDER BY 
    ua.UpVotes DESC;
