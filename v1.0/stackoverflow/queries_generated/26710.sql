WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only
),
TopTagPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5 -- Top 5 questions per tag
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.UpVotes - ue.DownVotes AS NetVotes,
        ue.CommentCount,
        ue.BadgeCount,
        RANK() OVER (ORDER BY ue.UpVotes DESC) AS VoteRank
    FROM 
        UserEngagement ue
    WHERE 
        ue.CommentCount > 0 -- Only users with comments
)
SELECT 
    ttp.PostId,
    ttp.Title AS QuestionTitle,
    ttp.CreationDate AS QuestionCreationDate,
    ttp.ViewCount,
    ttp.AnswerCount,
    tu.DisplayName AS TopUserName,
    tu.NetVotes,
    tu.CommentCount,
    tu.BadgeCount
FROM 
    TopTagPosts ttp
JOIN 
    TopUsers tu ON ttp.OwnerUserId = tu.UserId
ORDER BY 
    ttp.ViewCount DESC, tu.NetVotes DESC
LIMIT 10; -- Retrieve top 10 questions with their engagement metrics
