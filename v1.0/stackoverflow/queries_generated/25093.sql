WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS t(TagName)
    WHERE 
        pt.Name = 'Question' AND p.AcceptedAnswerId IS NOT NULL
    GROUP BY 
        p.Id, pt.Name
),

TopQuestions AS (
    SELECT 
        PostId, Title, CreationDate, Score, ViewCount, Tags
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),

UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),

EngagingUsers AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.CommentCount,
        ue.UpVoteCount,
        ue.DownVoteCount,
        RANK() OVER (ORDER BY ue.UpVoteCount DESC) AS UserRank
    FROM 
        UserEngagement ue
    WHERE 
        ue.CommentCount > 5
)

SELECT 
    tq.PostId,
    tq.Title,
    tq.CreationDate,
    tq.Score,
    tq.ViewCount,
    tq.Tags,
    eu.DisplayName AS TopEngagingUser,
    eu.UpVoteCount,
    eu.DownVoteCount
FROM 
    TopQuestions tq
JOIN 
    EngagingUsers eu ON tq.PostId IN (
        SELECT 
            p.Id 
        FROM 
            Posts p 
        WHERE 
            p.OwnerUserId = eu.UserId
    )
ORDER BY 
    tq.Score DESC, 
    eu.UpVoteCount DESC;
